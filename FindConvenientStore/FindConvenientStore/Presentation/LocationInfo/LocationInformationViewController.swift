//
//  LocationInformationViewController.swift
//  FindConvenientStore
//
//  Created by 장선영 on 2022/03/08.
//

import UIKit
import CoreLocation
import RxSwift
import RxCocoa
import SnapKit

class LocationInformationViewController: UIViewController {
    let disposebag = DisposeBag()
    let locationManager = CLLocationManager()
    
    let mapView = MTMapView()
    let currentLocationButton = UIButton()
    let detailList = UITableView()
    let detailListBackgroundView = DetailListBackgroundView()
    let viewModel = LocationInformationViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self
        
        bind(viewModel)
        attribute()
        layout()
    }

    private func bind(_ viewModel: LocationInformationViewModel) {
        detailListBackgroundView.bind(viewModel.detailListBackgroundViewModel)
        
        viewModel.setMapCenter
            .emit(to: mapView.rx.setMapCenterPoint)
            .disposed(by: disposebag)
        
        viewModel.errorMessage
            .emit(to: self.rx.presentAlertController)
            .disposed(by: disposebag)
        
        viewModel.detailListCellData
            .drive(detailList.rx.items) { tableView, row, data in
                let cell = tableView.dequeueReusableCell(withIdentifier: "DetailListCell", for: IndexPath(row: row, section: 0)) as! DetailListCell
                cell.setData(data)
                return cell
            }
            .disposed(by: disposebag)
        
        viewModel.detailListCellData
            .map{ $0.compactMap { $0.point }}
            .drive(self.rx.addPOIItems)
            .disposed(by: disposebag)
        
        viewModel.scrollToSelectedLocation
            .emit(to: self.rx.showSelectedLocation)
            .disposed(by: disposebag)
        
        detailList.rx.itemSelected
            .map { $0.row }
            .bind(to: viewModel.detailListItemSelected)
            .disposed(by: disposebag)
        
        currentLocationButton.rx.tap
            .bind(to: viewModel.currentLocationButtonTapped)
            .disposed(by: disposebag)
        
    }
    
    private func attribute() {
        title = "내 주변 편의점 찾기"
        view.backgroundColor = .white
        
        mapView.currentLocationTrackingMode = .onWithoutHeadingWithoutMapMoving
        
        currentLocationButton.setImage((UIImage(systemName: "location.fill")), for: .normal)
        currentLocationButton.backgroundColor = .white
        currentLocationButton.layer.cornerRadius = 20
        
        detailList.register(DetailListCell.self, forCellReuseIdentifier: "DetailListCell")
        detailList.separatorStyle = .none
        detailList.backgroundView = detailListBackgroundView
        
    }
    
    private func layout() {
        [mapView,currentLocationButton,detailList].forEach {
            view.addSubview($0)
        }
        
        mapView.snp.makeConstraints {
            $0.top.left.trailing.equalTo(view.safeAreaLayoutGuide)
            $0.bottom.equalTo(view.snp.centerY).offset(100)
        }

        currentLocationButton.snp.makeConstraints {
            $0.bottom.equalTo(detailList.snp.top).offset(-12) //offset(-12)
            $0.leading.equalTo(mapView).inset(12) //offset(12_
            $0.width.height.equalTo(40)
        }
        
        detailList.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
            $0.top.equalTo(mapView.snp.bottom)
        }
    }
}

extension LocationInformationViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse, .notDetermined:
            return
        default:
            viewModel.mapViewError.accept(MTMapViewError.locationAuthorizationDenied.errorDescription)
            return
        }
    }
}

extension LocationInformationViewController: MTMapViewDelegate {
    func mapView(_ mapView: MTMapView!, updateCurrentLocation location: MTMapPoint!, withAccuracy accuracy: MTMapLocationAccuracy) {
        #if DEBUG
        viewModel.currentLocation.accept(MTMapPoint(geoCoord: MTMapPointGeo(latitude: 37.394225, longitude: 127.110341)))
        #else
        viewModel.currentLocation.accept(location)
        #endif
    }
    
    func mapView(_ mapView: MTMapView!, finishedMapMoveAnimation mapCenterPoint: MTMapPoint!) {
        viewModel.mapCenterPoint.accept(mapCenterPoint)
    }
    
    func mapView(_ mapView: MTMapView!, selectedPOIItem poiItem: MTMapPOIItem!) -> Bool {
        //poiItem -> ping 표시 값
        
        viewModel.selectPOIItem.accept(poiItem)
        return false
    }
    
    func mapView(_ mapView: MTMapView!, failedUpdatingCurrentLocationWithError error: Error!) {
        viewModel.mapViewError.accept(error.localizedDescription)
    }
}

extension Reactive where Base: MTMapView {
    var setMapCenterPoint: Binder<MTMapPoint> {
        return Binder(base) { base, point in
            base.setMapCenter(point, animated: true)
        }
    }
}

extension Reactive where Base: LocationInformationViewController {
    var presentAlertController: Binder<String> {
        return Binder(base) { Base, message in
            let alertController = UIAlertController(title: "문제가 발생했어요", message: message, preferredStyle: .alert)
            let alertAction = UIAlertAction(title: "확인", style: .default, handler: nil)
            alertController.addAction(alertAction)
            base.present(alertController, animated: true, completion: nil)
        }
    }
    
    var showSelectedLocation: Binder<Int> {
        return Binder(base) { base, row in
            let indexPath = IndexPath(row: row, section: 0)
            base.detailList.selectRow(at: indexPath, animated: true, scrollPosition: .top)
        }
    }
    
    var addPOIItems: Binder<[MTMapPoint]> {
        return Binder(base) { base, points in
            let items = points
                .enumerated()
                .map { offset, point -> MTMapPOIItem in
                    
                    let mapPOIItem = MTMapPOIItem()
                    mapPOIItem.mapPoint = point
                    mapPOIItem.markerType = .redPin
                    mapPOIItem.showAnimationType = .springFromGround
                    mapPOIItem.tag = offset
                    
                    return mapPOIItem
                }
            
            base.mapView.removeAllPOIItems()
            base.mapView.addPOIItems(items)
        }
    }
}
